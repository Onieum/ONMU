package com.onmu.api.web;

import com.onmu.api.security.AuthenticatedUser;
import com.onmu.api.service.FriendService;
import com.onmu.api.web.dto.AddFriendRequest;
import com.onmu.api.web.dto.FriendResponse;
import com.onmu.api.web.dto.UpdateFriendRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class FriendController {
  private final FriendService friendService;

  public FriendController(FriendService friendService) {
    this.friendService = friendService;
  }

  @GetMapping("/me/friends")
  public List<FriendResponse> friends(@AuthenticationPrincipal AuthenticatedUser user) {
    return friendService.friends(user.userId());
  }

  @GetMapping("/search")
  public List<FriendResponse> search(
    @AuthenticationPrincipal AuthenticatedUser user,
    @RequestParam("query") String query
  ) {
    return friendService.search(user.userId(), query);
  }

  @PostMapping("/me/friends")
  public ResponseEntity<FriendResponse> addFriend(
    @AuthenticationPrincipal AuthenticatedUser user,
    @Valid @RequestBody AddFriendRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(friendService.addFriend(user.userId(), request));
  }

  @PatchMapping("/me/friends/{friendUserId}")
  public FriendResponse updateFriend(
    @AuthenticationPrincipal AuthenticatedUser user,
    @PathVariable String friendUserId,
    @RequestBody UpdateFriendRequest request
  ) {
    return friendService.updateFriend(
      user.userId(),
      friendUserId,
      request == null ? new UpdateFriendRequest(null, null) : request
    );
  }

  @DeleteMapping("/me/friends/{friendUserId}")
  public ResponseEntity<Void> deleteFriend(
    @AuthenticationPrincipal AuthenticatedUser user,
    @PathVariable String friendUserId
  ) {
    friendService.deleteFriend(user.userId(), friendUserId);
    return ResponseEntity.noContent().build();
  }
}
